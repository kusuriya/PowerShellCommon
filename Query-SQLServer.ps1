function Query-SQLServer
{
        	<#
        	.DESCRIPTION
        		This will open connections and issue queries against an MSSQL server.
        	.PARAMETER
        		Query
        			The Parameter is the query that will be passed to the SQL server.
        			
        	.PARAMETER
        		Database
        			Specifies the database to connect to.
        			
        	.PARAMETER
        		Server
        			Specifies the server to connect to.
        			
        	.PARAMETER
        		ConnectionString
        			Allows you to specify a raw MSSQL connection string.
        
        .PARAMETER
        		Credential
        			Takes a PSCredential object and allows you to pull it into the connection string builder.
        			
        	.PARAMETER
        		Parameters
        			Takes a hashtable input and creates parameters to be consumed by the SQL query.
        			
        	.PARAMETER
        		Timeout
        			Let the SQL server know how long you are willing to wait for the query to return something before timeing out.
        
        	.EXAMPLE
        		 Query-SQLServer -Server SQL1 -Database AutoMation -Query $("DECLARE @SQL nvarchar(max); set @SQL = 'Select * from ' + @table; exec(@SQL)") -Parameters @{'table' = $Table}
        	
        	.EXAMPLE
        		 Query-SQLServer -ConnectionString "Data Source=SQLServer.lan.contoso.com; Integrated Security=SSPI;Database=Automation;Username=Root;password=tor" -Query $("DECLARE @SQL nvarchar(max); set @SQL = 'Select * from ' + @table; exec(@SQL)") -Parameters @{'table' = $Table}
        			
        	.NOTES
        		Author: Jason Barbier <jabarb@corrupted.io>
        #>
        [cmdletbinding()]
        param
        (
                [parameter(position=1,Mandatory=$true, HelpMessage="This function requires a query!")]
                [string]$Query = $null,
                [parameter(Position=2, HelpMessage="This takes an MSSQL Connection String")]
                [string]$ConnectionString = $null,
                [parameter(Position=3, HelpMessage="Please specify user credentials in a PSCredential object")]
                [PSCredential]$Credential,
                [parameter(Position=4, HelpMessage="What is the default database you are going to connect to?")]
                [string]$Database = $null,
                [parameter(Position=5, HelpMessage="What server is the database on")]
                [string]$Server = $null,
                [parameter(Position=6, HelpMessage="This takes a hashtable to pass parameters to a parmeterized query")]
                [hashtable]$Parameters=@{},
                [parameter(Position=7, HelpMessage="How long should we wait?")]
        	[int]$Timeout = 30
        	
        )
        
        # If the user did not supply a full connection string to us we will need to build one.
        if (!$ConnectionString)
        {
        	# If we were given a credential we should use it.
                if ($Credential) {
                    $Builder = New-Object System.Data.SqlClient.SqlConnectionStringBuilder
                    $Builder.'Data Source' = $Server
                    $Builder.'Integrated Security' = $false
                    $Builder.'Username' = $Credential.GetNetworkCredential().Username
                    $Builder.'Password' = $Credential.GetNetworkCredential().Password
                    $Builder.'Initial Catalog' = $Database
                    $ConnectionString = $Builder.ConnectionString
                }
        	# Otherwise just use integrated auth
                else {
                    $Builder = New-Object System.Data.SqlClient.SqlConnectionStringBuilder
                    $Builder.'Data Source' = $Server
                    $Builder.'Integrated Security' = $true
                    $Builder.'Initial Catalog' = $Database
                    $ConnectionString = $Builder.ConnectionString
                }
        }
        
        $Connection = new-object system.data.SqlClient.SQLConnection($ConnectionString)
        $Command = new-object system.data.sqlclient.sqlcommand($Query,$connection)
        
        # Setup config stuff
        $Command.CommandTimeout=$Timeout
        
        foreach ($Parameter in $Parameters.Keys)
        {
        	[Void]$Command.Parameters.AddWithValue("@$Parameter",$Parameters[$Parameter])
        }
        
        $Connection.Open()
        
        $Adapter = New-Object System.Data.sqlclient.sqlDataAdapter($Command)
        $Dataset = New-Object System.Data.DataSet
        [Void]$Adapter.Fill($dataSet)
        return $Dataset.Tables
        
        # Cleanup
        $Connection.Close()
        Remove-Variable -Name 'ServerInstance','Query','Adapter','DataSet','Connection','Command'
} # End Query-SQLServer
