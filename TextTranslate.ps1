Import-Module "$PSScriptRoot\setup.psm1"
function IssueCognitiveApiToken {
    
    # Headers required for issuing token
    $tokenUriHeader = @{'Ocp-Apim-Subscription-Key' = $accountKey }
    $tokenUriQuery = "?Subscription-Key=$accountKey"
    $tokenUri = $tokenServiceUrl+$tokenUriQuery

    # Authentication to Cognitive Services - request token.
    $tokenResult = Invoke-WebRequest `
    -Method Post `
    -Headers $tokenUriHeader `
    -UseBasicParsing `
    -Uri "$tokenUri" 

    # Return the authentication token
    return $tokenResult
}

function TranslateQuestItem {
    param (
        [Parameter(Mandatory=$true)]
        [string]$translateText,

        [Parameter(Mandatory=$true)]
        [string]$FromLang,

        [Parameter(Mandatory=$true)]
        [string]$ToLang
    )

    # Build params for API token call
    $token = IssueCognitiveApiToken
    $auth = "Bearer "+$token
    $header = @{Authorization = $auth; 'Ocp-Apim-Subscription-Key' = $accountKey;}

    $translation = TranslateField -translateText $translateText -Header $header -FromLang $fromLang -ToLang $toLang

    Write-Host $translation
}

function TranslateField {
    param (
        [Parameter(Mandatory=$true)]
        [string]$translateText,

        [Parameter(Mandatory=$true)]
        [System.Collections.Hashtable]$Header,
        
        [Parameter(Mandatory=$true)]
        [string]$FromLang,

        [Parameter(Mandatory=$true)]
        [string]$ToLang
    )
    
    # Build translation API query parameters 
    $query = "&from="  + $FromLang
    $query += "&to=" + $ToLang
    $query += "&textType=html"
    $query += "&contentType=application/json"
    $apiUri = $requestTranslationUrl+$query
    
    # Sanitize the field's value into a JSON object
    $obj = @{Text="$translateText" }
    $requestObject = $obj | ConvertTo-Json -depth 100 |
     % { [System.Text.RegularExpressions.Regex]::Unescape($_) } 
         

    try 
    {
        # Call the API
        $result = Invoke-WebRequest `
            -Method Post `
            -Headers $Header `
            -ContentType:"application/json" `
            -Body "[$requestObject]" `
            -UseBasicParsing `
            -Uri "$apiUri" | Select-Object -Expand Content | ConvertFrom-Json

            # Return the translated text
            return $result.translations.text

    } 
    catch [System.Net.WebException]
    {
        # An error occured calling the API
        Write-Host 'Error calling API' -ForegroundColor Red
        Write-Host $Error[0] -ForegroundColor Red
        return $null
    } 
}

# Call Translate-Item and pass in params
TranslateQuestItem -translateText 'Das wurde von deutsch in englisch übersetzt.' -FromLang $fromLang -ToLang $toLang
