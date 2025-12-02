import os
import logging
from dotenv import load_dotenv
from ..error import InternalError

load_dotenv()

class Config:
    version = "0.1.0"
    title = "race"

    app_settings = {
        'db_name': os.environ.get('MONGODB_DBNAME'),
        'mongodb_url': os.environ.get('MONGODB_URL'),
        'max_db_conn_count': os.environ.get('MAX_CONNECTIONS_COUNT'),
        'min_db_conn_count': os.environ.get('MIN_CONNECTIONS_COUNT'),
    }

    @classmethod
    def app_settings_validate(cls):
        for k, v in cls.app_settings.items():
            if None is v:
                logging.error(f'Config variable error. {k} cannot be None')
                raise InternalError([{
                    "message": "Server configure error"
                }])
