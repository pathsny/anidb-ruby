cd web && bundle exec rerun --pattern "**/*.{rb,html}" \
  --ignore public/ \
  "bundle exec puma -b tcp://0.0.0.0:9393 config.ru" 
