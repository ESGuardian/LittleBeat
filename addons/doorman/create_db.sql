CREATE ROLE doorman WITH LOGIN PASSWORD '7aWNLur6dyy97LYylawz';
CREATE DATABASE doorman;
ALTER DATABASE doorman OWNER TO doorman;
GRANT ALL PRIVILEGES ON DATABASE doorman TO doorman;