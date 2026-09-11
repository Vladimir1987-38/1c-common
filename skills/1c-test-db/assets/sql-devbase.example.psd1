# Локальные настройки прямого доступа к тестовой SQL-базе этого проекта.
# Заполните Server и Database. Адрес сервера 1С сюда не подходит.
# Файл не подключается к базе. Каждое подключение требует разрешения пользователя.
# Для файловой базы 1С прямой SQL неприменим: оставьте Enabled = $false.
@{
    Project = '__PROJECT__'
    Enabled = $false # Включить после заполнения; это НЕ разрешение на подключение.
    Server = '' # SQL Server: SERVER\INSTANCE либо tcp:SERVER,PORT
    Database = '' # Имя именно тестовой базы в SQL Server
    Authentication = 'Windows' # Windows или SqlPassword
    UserName = '' # Только для SqlPassword
    PasswordEnvironmentVariable = '' # Имя переменной среды с паролем, НЕ сам пароль
    Encrypt = $true
    TrustServerCertificate = $false
    ConnectTimeoutSeconds = 5
    CommandTimeoutSeconds = 20
    LockTimeoutMilliseconds = 3000
}
