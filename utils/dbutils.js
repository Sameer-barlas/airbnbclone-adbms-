require("dotenv").config();
const mysql = require("mysql2");

const getDbConfig = () => {
  const databaseUrl = process.env.DATABASE_URL || process.env.TIDB_DATABASE_URL;

  if (databaseUrl) {
    const isTiDB = databaseUrl.includes('tidbcloud.com');
    const sslOption = (process.env.DB_SSL === 'true' || isTiDB || databaseUrl.includes('ssl='))
      ? {
          minVersion: 'TLSv1.2',
          rejectUnauthorized: process.env.DB_SSL_REJECT_UNAUTHORIZED === 'false' ? false : true
        }
      : undefined;

    return {
      uri: databaseUrl,
      waitForConnections: true,
      connectionLimit: Number(process.env.DB_CONNECTION_LIMIT) || 10,
      queueLimit: 0,
      enableKeepAlive: true,
      keepAliveInitialDelay: 10000,
      connectTimeout: 20000,
      ssl: sslOption
    };
  }

  const host = process.env.DB_HOST || "127.0.0.1";
  const isTiDB = host.includes('tidbcloud.com');
  const port = Number(process.env.DB_PORT) || (isTiDB ? 4000 : 3306);
  const isSsl = process.env.DB_SSL === "true" || isTiDB;

  return {
    host,
    port,
    user: process.env.DB_USER || "root",
    password: process.env.DB_PASSWORD !== undefined ? process.env.DB_PASSWORD : "root",
    database: process.env.DB_NAME || "air_bnb",
    waitForConnections: true,
    connectionLimit: Number(process.env.DB_CONNECTION_LIMIT) || 10,
    queueLimit: 0,
    enableKeepAlive: true,
    keepAliveInitialDelay: 10000,
    connectTimeout: 20000,
    ssl: isSsl ? {
      minVersion: 'TLSv1.2',
      rejectUnauthorized: process.env.DB_SSL_REJECT_UNAUTHORIZED === 'false' ? false : true
    } : undefined
  };
};

const pool = mysql.createPool(getDbConfig());

module.exports = pool.promise();
