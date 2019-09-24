from django.conf import settings
from django.shortcuts import redirect
from django.conf.urls import include, url

from tcms.kiwi_auth import views
from tcms.urls import urlpatterns


if hasattr(settings, 'DISABLE_REGISTRATION') and settings.DISABLE_REGISTRATION:
    urlpatterns.insert(0, url(r'^accounts/register/$', lambda request: redirect('/', permanent=True)))
    urlpatterns.insert(0, url(r'^accounts/passwordreset/$', lambda request: redirect('/', permanent=True)))

urlpatterns += [
    url('', include('social_django.urls', namespace='social')),
]
