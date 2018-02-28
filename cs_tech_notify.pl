#!/usr/bin/perl

use Data::Dumper;
use JSON;
use POSIX qw(strftime);

my $metrics = {};

my $prom_hash = { 
'mpdb_leads_assinged' => 'sum(delta(collectd_statsd_derive{statsd="prod.job-csdb.LEAD_ASSIGNED_COUNT"}[2h]))',
'mpdb_app_assinged'   => 'sum(delta(collectd_statsd_derive{statsd="prod.job-csdb.APP_ASSIGNED_COUNT"}[2h]))',
'incoming_call_count' => 'sum(delta(collectd_statsd_derive{statsd="prod.csdb.INCOMING_CALL_COUNT"}[15m]))',
'outgoing_call_count' => 'sum(delta(collectd_statsd_derive{statsd=~"prod.csdb.*_OUTGOING_CALL_COUNT"}[15m]))'
};



my $influx_hash = { 
'mpdb_recently_created_leads_db1' => 'SELECT "value" FROM "mpdb_recently_created_leads.gauge-count" WHERE ("host" =~ /prod-db-01/) order by desc limit 1',
'mpdb_recently_created_leads_db3' => 'SELECT "value" FROM "mpdb_recently_created_leads.gauge-count" WHERE ("host" =~ /prod-db-03/) order by desc limit 1',

'mpdb_unassigned_leads_db1' => 'SELECT "value" FROM "mpdb_unassigned_leads.gauge-count" WHERE ("host" =~ /prod-db-01/) order by desc limit 1;',
'mpdb_unassigned_leads_db2' => 'SELECT "value" FROM "mpdb_unassigned_leads.gauge-count" WHERE ("host" =~ /prod-db-02/) order by desc limit 1;',
'mpdb_unassigned_leads_db3' => 'SELECT "value" FROM "mpdb_unassigned_leads.gauge-count" WHERE ("host" =~ /prod-db-03/) order by desc limit 1;',

'mpdb_unassigned_apps_db1' => 'SELECT "value" FROM "mpdb_unassigned_apps.gauge-count" WHERE ("host" =~ /prod-db-01/) order by desc limit 1;',
'mpdb_unassigned_apps_db2' => 'SELECT "value" FROM "mpdb_unassigned_apps.gauge-count" WHERE ("host" =~ /prod-db-02/) order by desc limit 1;',
'mpdb_unassigned_apps_db3' => 'SELECT "value" FROM "mpdb_unassigned_apps.gauge-count" WHERE ("host" =~ /prod-db-03/) order by desc limit 1;',


 'mpdb_contact_upload' => 'SELECT "value" FROM "mpdb_contact_upload_backlog.gauge-count" order by desc limit 1;',

 'insdb_recently_created_leads' => ' SELECT "value" FROM "insdb_recently_created_leads.gauge-count" WHERE ("host" =~ /prod-db/)  order by desc limit 1;',

 'insdb_recently_created_apps.gauge-count' => ' SELECT "value" FROM "insdb_recently_created_apps.gauge-count" WHERE ("host" =~ /prod-db/)  order by desc limit 1; ',

 'insdb_unassigned_leads' => ' SELECT "value" FROM "insdb_unassigned_leads.gauge-count" WHERE ("host" =~ /prod-db/) order by desc limit 1; ',

 'insdb_recently_created_apps' => ' SELECT "value" FROM "insdb_recently_created_apps.gauge-count" WHERE ("host" =~ /prod-db/)  order by desc limit 1; ',

 'insdb_unassigned_leads' =>  ' SELECT "value" FROM "insdb_unassigned_leads.gauge-count" WHERE ("host" =~ /prod-db/) order by desc limit 1; ',

 'insdb_unassigned_apps' => ' SELECT "value" FROM "insdb_unassigned_apps.gauge-count" WHERE ("host" =~ /prod-db/) order by desc limit 1;',

 'insdb_contact_upload_backlog' => 'SELECT "value" FROM "insdb_contact_upload_backlog.gauge-count" order by desc limit 1;',

 'total_time_in_ms-global-processing' => 'SELECT max("value")*60 FROM "total_time_in_ms-global-processing" WHERE "host" =~ /B062APP/ order by desc limit 1;',

 'total_time_in_ms-global-processing' => ' SELECT max("value") FROM "total_time_in_ms-global-processing" WHERE "host" =~ /B063APP/ order by desc limit 1; ',


 'tata_p2p_ping' => 'SELECT last("value") FROM "Tata-P2P_ping.gauge-100_1_1_2"  order by desc limit 1;',
 'ambattur_mpls' => 'SELECT last("value") FROM "Ambattur-Mpls_ping.gauge-192_168_42_26"   order by desc limit 1;',

};



foreach my $query (keys %{$prom_hash}) {
my $response  =  qx(curl -s -g http://10.1.2.34:9090/api/v1/query?query='$prom_hash->{$query}') ;
$response = decode_json ($response);
$metrics->{$query} = $response->{'data'}->{'result'}[0]->{'value'}[1]
}

foreach my $query (keys %{$influx_hash}) {

    my $cmd  =  'curl -s -g http://10.1.2.32:8086/query?pretty=true --data-urlencode db=prod_tags --data-urlencode q=\'' . $influx_hash->{$query} . '\' -u ps:ps@123' ;
    my $response = `$cmd`;
    $response = decode_json ($response);
    my $value =$response->{"results"}[0]->{"series"}[0]->{"values"}[0][1];
    $metrics->{$query} = $value;
}


print Dumper ($metrics);


=head
#Influx test
my $cmd = qx ( curl -s -g 'http://10.1.2.32:8086/query?pretty=true' --data-urlencode "db=prod_tags" --data-urlencode 'q=SELECT "value" FROM "mpdb_recently_created_leads.gauge-count" WHERE ("host" =~ /prod-db-01/) order by desc limit 1;' -u root:root );
$response = decode_json ($cmd);
print Dumper($response);

#Prometheus test
my $cmd = qx ( curl -s -g 'http://10.1.2.34:9090/api/v1/query?query=sum(delta(collectd_statsd_derive{statsd="prod.job-csdb.LEAD_ASSIGNED_COUNT"}[2h]))' );
$response = decode_json ($cmd);
die "Error connecting to $url" unless defined $response;
$response = decode_json ($response);
print Dumper($response);
print Dumper ($response->{'data'}->{'result'}[0]->{'value'}[0]);
print Dumper ($response->{'data'}->{'result'}[0]->{'value'}[1]);

my $epoch = $response->{'data'}->{'result'}[0]->{'value'}[0];
my $value = $response->{'data'}->{'result'}[0]->{'value'}[0];
print strftime("%m/%d/%Y %H:%M:%S",localtime($epoch));
print $value;
