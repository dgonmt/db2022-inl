package se.iths;

import java.io.IOException;
import java.util.Properties;

public class Configuration {

    public static final String PROPERTIES_FILE = "application.properties";
    private final String dbUrl;
    private final String dbUser;
    private final String dbPassword;


    public Configuration() {
        Properties property = new Properties();

        try {
            property.load(Configuration.class.getClassLoader().getResourceAsStream(PROPERTIES_FILE));
        } catch (IOException e) {
            e.printStackTrace();
        }
        dbUrl = property.getProperty("db.url");
        dbUser = property.getProperty("db.user");
        dbPassword = property.getProperty("db.password");
    }

    public String toString() {
        StringBuffer stringBuffer = new StringBuffer("");
        stringBuffer.append("dbUser=");
        stringBuffer.append(dbUser);
        stringBuffer.append("\n dbPassword=");
        stringBuffer.append(dbPassword);
        stringBuffer.append("\n dbURL");
        stringBuffer.append(dbUrl);
        return stringBuffer.toString();
    }

    public String getDbUrl() {
        return dbUrl;
    }
    public String getDbUser() {
        return dbUser;
    }
    public String getDbPassword() {
        return dbPassword;
    }

}
