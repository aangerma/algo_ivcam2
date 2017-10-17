function adoConnection = getVerifier()
    dataSource='haisqldev024,3184';
    dataBase = 'AlgoSQL';
    userId='matlab';
    password='algo123!';
    connectionString = sprintf('PROVIDER=SQLOLEDB; Data Source=%s; DataBase=%s; User Id=%s; Password=%s;',dataSource,dataBase,userId,password);
    adoConnection = adodb_connect(connectionString,1);
end