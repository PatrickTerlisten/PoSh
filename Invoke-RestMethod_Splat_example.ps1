# Username and Password
$user = "admin"
$pass = "password"

# Hashtable that includes data
$rawbody = @{
    first='joe'
    lastname='doe'
}

# Convert ashtable to JSON format
$jsonbody = $rawbody | ConvertTo-Json

# Hashtable that includes the parameters for the Invoke-RestMethod call
$params = @{uri = 'https://192.168.199.17:9443/rest/v1/config/edgeservice/view';
                   Method = 'Get';
                   Headers = @{Authorization = 'Basic ' + [System.Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${user}:${pass}"));}
                   Body = $jsonbody;
                   ContentType = 'application/json'
   }

Invoke-RestMethod @params
