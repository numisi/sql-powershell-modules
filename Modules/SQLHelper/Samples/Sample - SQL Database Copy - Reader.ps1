﻿cls

$ErrorActionPreference = "Stop"

$currentPath = (Split-Path $MyInvocation.MyCommand.Definition –Parent)

Import-Module "$currentPath\..\SQLHelper.psm1" -Force

$sourceConnStr = "Integrated Security=SSPI;Persist Security Info=False;Initial Catalog=AdventureWorksDW2012;Data Source=.\sql2014"

$destinationConnStr = "Integrated Security=SSPI;Persist Security Info=False;Initial Catalog=DestinationDB;Data Source=.\sql2014"

$tables = @("[dbo].[DimReseller]", "[dbo].[FactResellerSales]")

$steps = $tables.Count
$i = 1;

$tables |% {
		
	$sourceTableName = $_
	$destinationTableName = $sourceTableName
	
	Write-Progress -activity "Tables Copy" -CurrentOperation "Executing source query over '$sourceTableName'" -PercentComplete (($i / $steps)  * 100) -Verbose
	
	# Query the datasource
	
	$reader = Invoke-SQLCommand -executeType "Reader" -connectionString $sourceConnStr -commandText "select * from $sourceTableName" -Verbose				
	
	# Create the table if not exists
	
	if (-not (Test-SQLTableExists -connectionString $destinationConnStr -tableName $destinationTableName -verbose))
	{								
		New-SQLTable -connectionString $destinationConnStr -data @{reader = $reader} -tableName $destinationTableName -force -Verbose
	}	
	
	# Bulk copy into the destination table
	
	Invoke-SQLBulkCopy -connectionString $destinationConnStr -data @{reader = $reader} -tableName $destinationTableName -Verbose
	
	$reader.Dispose()	
					
	$i++;
}

Write-Progress -activity "Tables Copy" -Completed
