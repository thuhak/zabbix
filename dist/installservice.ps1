Get-Service "zabbix agent" -ErrorAction SilentlyContinue | Out-Null
if (!$?)
{
    C:\zabbix_agent\zabbix_agentd.exe -c C:\zabbix_agent\zabbix.conf -i > $null 2>&1 
    $out = @'
    {
        "changed" : "True",
        "comment" : "zabbix agent has been installed"
    }
'@
    write-host $out 
}

