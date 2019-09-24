import os

from django.conf import settings


settings.STATICFILES_DIRS.insert(0, os.path.join(settings.TCMS_ROOT_PATH, 'addons_static'))
