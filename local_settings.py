import os

from django.conf import settings


# SECRET_KEY =

settings.STATICFILES_DIRS.insert(0, os.path.join(settings.TCMS_ROOT_PATH, 'addons_static'))
settings.TEMPLATES[0]['DIRS'].insert(0, os.path.join(settings.TCMS_ROOT_PATH, 'addons_templates'))
ROOT_URLCONF = 'addons.urls'

settings.INSTALLED_APPS.extend([
    'social_django',
])

SOCIAL_AUTH_URL_NAMESPACE = 'social'

settings.PUBLIC_VIEWS.extend([
    'social_django.views.auth',
    'social_django.views.complete',
    'social_django.views.disconnect',
])

settings.TEMPLATES[0]['OPTIONS']['context_processors'].extend([
    'social_django.context_processors.backends',
    'social_django.context_processors.login_redirect',
])

SOCIAL_AUTH_PIPELINE = [
    'social_core.pipeline.social_auth.social_details',
    'addons.pipeline.email_is_required',
    'addons.pipeline.filter_email_domains',
    'social_core.pipeline.social_auth.social_uid',
    'social_core.pipeline.social_auth.social_user',
    'social_core.pipeline.user.get_username',
    'social_core.pipeline.user.create_user',
    'social_core.pipeline.social_auth.associate_user',
    'social_core.pipeline.social_auth.load_extra_data',
    'social_core.pipeline.user.user_details',
    'addons.pipeline.random_password',
    'addons.pipeline.initiate_defaults',
]

SOCIAL_AUTH_POSTGRES_JSONFIELD = True
SOCIAL_AUTH_ADMIN_USER_SEARCH_FIELDS = ['username', 'first_name', 'email']

AUTHENTICATION_BACKENDS = (
    'social_core.backends.google.GoogleOAuth2',
    'django.contrib.auth.backends.ModelBackend',
)

AUTO_APPROVE_NEW_USERS = True
DISABLE_REGISTRATION = True
ALLOWED_EMAIL_DOMAINS = []

# Google OAuth Client Id and Secret
# SOCIAL_AUTH_GOOGLE_OAUTH2_KEY =
# SOCIAL_AUTH_GOOGLE_OAUTH2_SECRET =

# Amazon SES
# DEFAULT_FROM_EMAIL = 'kiwi@example.com'
# EMAIL_SUBJECT_PREFIX = '[Kiwi-TCMS] '
# EMAIL_BACKEND = 'django_ses.SESBackend'
# AWS_SES_ACCESS_KEY_ID =
# AWS_SES_SECRET_ACCESS_KEY =
