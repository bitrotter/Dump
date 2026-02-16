import winston from 'winston';

const logFormat = winston.format.combine(
  winston.format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss' }),
  winston.format.errors({ stack: true }),
  winston.format.printf((info) => `${info.timestamp} [${info.level.toUpperCase()}] ${info.label}: ${info.message}`)
);

export function createLogger(label) {
  return winston.createLogger({
    level: process.env.LOG_LEVEL || 'info',
    format: logFormat,
    defaultMeta: { label },
    transports: [
      new winston.transports.Console(),
      new winston.transports.File({
        filename: process.env.LOG_FILE || 'logs/app.log',
        maxsize: 5242880, // 5MB
        maxFiles: 5,
      }),
    ],
  });
}
