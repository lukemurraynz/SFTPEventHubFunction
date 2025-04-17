param($eventHubMessages, $TriggerMetadata)

Write-Host "PowerShell SFTP event hub trigger function called"

# Process each message
$eventHubMessages | ForEach-Object {
    # Get the records array from the message
    if ($_ -is [System.Management.Automation.OrderedHashtable] -or $_ -is [hashtable]) {
        if ($_.ContainsKey('records')) {
            Write-Host "Processing SFTP Storage events..."
            
            # Filter for StorageWrite operations with status code 200
            $filteredRecords = $_.records | Where-Object { 
                $_.category -eq "StorageWrite" -and $_.statusCode -eq 200 -and $_.operationName -eq "SftpCreate"
            }
            
            Write-Host "Found $($filteredRecords.Count) StorageWrite 200 operations"
            
            # Display only the requested information
            foreach ($record in $filteredRecords) {
                $output = [ordered]@{
                    'Operation'     = $record.operationName
                    'FileName'      = if ($record.properties.objectKey -match '^(?:[^/]*/){3}(.*)$') { $matches[1] } else { $record.properties.objectKey }
                    'UserID'        = $record.identity.requester.objectId
                    'UserIPAddress' = $record.callerIpAddress
                    'UserAgent'     = $record.properties.userAgentHeader
                    'Time'          = $record.time
                }
                
                # Output in a clean table format
                Write-Host "----------------------------------------"
                foreach ($key in $output.Keys) {
                    Write-Host "$($key.PadRight(12)): $($output[$key])"
                }
            }
            
            if ($filteredRecords.Count -gt 0) {
                Write-Host "----------------------------------------"
            }
        }
    }
    else {
        Write-Host "Message wasn't in the expected format"
    }
}
