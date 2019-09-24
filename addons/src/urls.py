from django.conf import settings
from django.conf.urls import include, url

from tcms.kiwi_auth import views
from tcms.urls import urlpatterns


if hasattr(settings, 'DISABLE_REGISTRATION') and settings.DISABLE_REGISTRATION:
    urlpatterns.insert(0, url(r'^accounts/register/$', views.LoginViewWithCustomTemplate.as_view(), name='tcms-register'))

urlpatterns += [
    url('', include('social_django.urls', namespace='social')),
]
