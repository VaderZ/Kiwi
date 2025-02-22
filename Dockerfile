FROM centos:centos7 as kiwi_root

RUN rpm -Uhv https://dl.fedoraproject.org/pub/epel/7/x86_64/Packages/e/epel-release-7-11.noarch.rpm && \
    yum -y --setopt=tsflags=nodocs install centos-release-scl && \
    yum -y --setopt=tsflags=nodocs install rh-python36-python mariadb-libs postgresql httpd mod_wsgi mod_ssl && \
    yum clean all

# Apache configuration for non-root users
EXPOSE 8080
EXPOSE 8443
COPY ./httpd-foreground /httpd-foreground
CMD /httpd-foreground
RUN sed -i 's/Listen 80/Listen 8080/' /etc/httpd/conf/httpd.conf && \
    sed -i 's/Listen 443/Listen 8443/' /etc/httpd/conf.d/ssl.conf && \
    sed -i 's!ErrorLog "logs/error_log"!ErrorLog "/dev/stderr"!' /etc/httpd/conf/httpd.conf && \
    sed -i 's!CustomLog "logs/access_log"!CustomLog "/dev/stdout"!' /etc/httpd/conf/httpd.conf && \
    sed -i 's!ErrorLog logs/ssl_error_log!ErrorLog "/dev/stderr"!' /etc/httpd/conf.d/ssl.conf && \
    sed -i 's!TransferLog logs/ssl_access_log!TransferLog "/dev/stdout"!' /etc/httpd/conf.d/ssl.conf && \
    sed -i 's!CustomLog logs/ssl_request_log!CustomLog "/dev/stdout"!' /etc/httpd/conf.d/ssl.conf && \
    rm -rf /run/httpd && mkdir /run/httpd && chmod -R a+rwx /run/httpd
COPY ./etc/kiwi-httpd.conf /etc/httpd/conf.d/

# make sure Python 3.6 is enabled by default
ENV PATH /venv/bin:/opt/rh/rh-python36/root/usr/bin${PATH:+:${PATH}} \
    LD_LIBRARY_PATH /opt/rh/rh-python36/root/usr/lib64${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}} \
    PKG_CONFIG_PATH /opt/rh/rh-python36/root/usr/lib64/pkgconfig${PKG_CONFIG_PATH:+:${PKG_CONFIG_PATH}} \
    XDG_DATA_DIRS "/opt/rh/rh-python36/root/usr/share:${XDG_DATA_DIRS:-/usr/local/share:/usr/share}" \
    VIRTUAL_ENV /venv

# copy virtualenv dir which has been built inside the kiwitcms/buildroot container
# this helps keep -devel dependencies outside of this image
COPY ./dist/venv/ /venv

# replace standard mod_wsgi with one compiled for Python 3
RUN ln -fs /venv/lib64/python3.6/site-packages/mod_wsgi/server/mod_wsgi-py36.cpython-36m-x86_64-linux-gnu.so \
           /usr/lib64/httpd/modules/mod_wsgi.so

COPY ./manage.py /Kiwi/
COPY ./etc/kiwitcms/ssl/ /Kiwi/ssl/
RUN sed -i "s/tcms.settings.devel/tcms.settings.product/" /Kiwi/manage.py

# create a mount directory so we can properly set ownership for it
RUN mkdir /Kiwi/uploads

# collect static files
RUN /Kiwi/manage.py collectstatic --noinput --link

# from now on execute as non-root
RUN chown -R 1001 /Kiwi/ /venv/ \
    /etc/pki/tls/certs/localhost.crt /etc/pki/tls/private/localhost.key
USER 1001

FROM kiwi_root as kiwi

USER 1001

COPY ./requirements/addons.txt /Kiwi/
RUN pip install --no-cache-dir -r /Kiwi/addons.txt

COPY ./addons/src/ /venv/lib64/python3.6/site-packages/addons/
COPY ./addons/templates/ /venv/lib64/python3.6/site-packages/tcms/addons_templates/
COPY ./addons/static/ /venv/lib64/python3.6/site-packages/tcms/addons_static/

# Add temp local_settings to collect static files
COPY ./static_links.py /venv/lib64/python3.6/site-packages/tcms/settings/local_settings.py
# woraround broken CSS which will break collectstatic
# because they refer to non-existing ../fonts/glyphicons-halflings-regular.eot (no fonts/ directory)
# remove django_tenants/templates/admin/index.html b/c it is ugly and b/c we use grapelli
RUN rm -rf /venv/lib64/python3.6/site-packages/tcms/node_modules/c3/htdocs/ \
           /venv/lib64/python3.6/site-packages/tcms/node_modules/eonasdan-bootstrap-datetimepicker/build/css/bootstrap-datetimepicker-standalone.css \
           /venv/lib64/python3.6/site-packages/tcms/node_modules/bootstrap-touchspin/demo/ \
           /venv/lib64/python3.6/site-packages/django_tenants/templates/admin/index.html

# collect static files again
RUN /Kiwi/manage.py collectstatic --clear --link --noinput

# Remove temp local_settings
RUN rm /venv/lib64/python3.6/site-packages/tcms/settings/local_settings.py
