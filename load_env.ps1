"Loading File..."
$creds = Import-Csv C:\aws\credentials.csv

"Setting Access Key..."
$ENV:AWS_ACCESS_KEY_ID = $creds.'Access key ID'
"Setting Secret..."
$ENV:AWS_SECRET_ACCESS_KEY = $creds.'Secret access key'

