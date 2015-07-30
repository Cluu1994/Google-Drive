### Google Drive gem with embed tools
[![GitHub version](https://badge.fury.io/gh/Aldogroup%2FGoogle-Drive.png)](http://badge.fury.io/gh/Aldogroup%2FGoogle-Drive)


# Use

Add to your config file this:
```
activate :gdrive, load_sheets: {
                                  en_CA: 'ca_en',
                                  fr_CA: 'ca_fr'
                                  # You can add more language if needed
                  }
```

You can also add a specific file:
```
activate :gdrive, load_sheets: { mail: 'my_email_brief_name'}
```
