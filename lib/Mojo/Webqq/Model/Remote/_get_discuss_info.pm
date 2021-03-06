sub Mojo::Webqq::Model::_get_discuss_info {
    my $self = shift;       
    my $did = shift;
    my $api_url  = 'http://d1.web2.qq.com/channel/get_discu_info';
    my @query_string = (
        did         =>  $did,
        vfwebqq     =>  $self->vfwebqq,
        clientid    =>  $self->clientid,
        psessionid  =>  $self->psessionid,
        t           =>  time(),
    );
    my $headers = {
        Referer  => 'http://d1.web2.qq.com/proxy.html?v=20151105001&callback=1&id=2',
        json     => 1,
    };

    my $json = $self->http_get($self->gen_url($api_url,@query_string),$headers);

    return unless defined $json;
    return undef if $json->{retcode}!=0;
    return undef unless exists $json->{result}{info};
    
    my %mem_list;
    my %mem_status;
    my %mem_info;
    my $minfo = [];

    for(@{ $json->{result}{info}{mem_list} }){
        $mem_list{$_->{mem_uin}}{ruin} = $_->{ruin};            
    }

    for(@{ $json->{result}{mem_status} }){
        $mem_status{$_->{uin}}{status} = $_->{status};
        $mem_status{$_->{uin}}{client_type} = $_->{client_type};
    }

    for(@{ $json->{result}{mem_info} }){
        $mem_info{$_->{uin}}{nick} = $_->{nick};
    }

    my $discuss_info = {
        did         =>  $json->{result}{info}{did},
        downer       =>  $json->{result}{info}{discu_owner},
        dname        =>  $json->{result}{info}{discu_name},
    };

    for(keys %mem_list){
        my $m = {
            id          => $_,  
            nick        => $mem_info{$_}{nick},
            ruin        => $mem_list{$_}{ruin},
            did         => $discuss_info->{did},
            downer      => $discuss_info->{downer},
            dname       => $discuss_info->{dname},
        };
        if(exists $mem_status{$_}){
            $m->{state} = $mem_status{$_}{status};
            $m->{client_type} = $self->code2client($mem_status{$_}{client_type});
        }
        else{
            $m->{state} = 'offline';
            $m->{client_type} = 'unknown';
        }
        $self->reform_hash($m);
        push @{$minfo},$m;
    }

    $self->reform_hash($discuss_info);
    $discuss_info->{ member } = $minfo if @$minfo>0;
    return $discuss_info;
}
1;
