local Config = {}

Config.TaxRate   = 0.005
Config.TaxTime   = "0 5 * * *"

Config.Processing = {
    batchSize   = 100,
    batchDelay  = 50,
    playerDelay = 10
}

Config.VehicleValues = {
    import = 500000,
    lokal  = 250000
}

Config.ImportBrands = {
    ['SatuMimpi'] = true,
    ['Debugmode'] = true
}

Config.ShowUIOnSpawn = true
Config.UIDisplayTime = 8000
Config.Debug         = false

Config.Tables = {
    players    = 'players',
    taxHistory = 'tax_history'
}

Config.BankTax = {
    TaxRate         = 0.001,
    TaxTime         = "0 4 * * *",
    MinimumBalance  = 1000000,
    ExemptAccounts  = {},
    ProcessingDelay = 10,
    HistoryTable    = 'bank_tax_history',
    AccountsTable   = 'bank_accounts_new'
}

return Config