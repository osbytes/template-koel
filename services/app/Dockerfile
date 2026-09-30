# Hub tags omit the leading "v" from koel/koel GitHub Releases
# (release v9.11.0 → image phanan/koel:v9.15.0). Review upstream-check PRs
# and strip "v" if a bot rewrite does not resolve on Docker Hub.
FROM phanan/koel:v9.15.0

COPY docker-entrypoint.sh /usr/local/bin/railway-entrypoint.sh
RUN chmod +x /usr/local/bin/railway-entrypoint.sh

ENTRYPOINT ["/usr/local/bin/railway-entrypoint.sh"]
CMD ["apache2-foreground"]
