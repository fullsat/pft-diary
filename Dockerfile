FROM jekyll/jekyll

RUN echo "Asia/Tokyo" > /etc/timezone
ENV TZ='Asia/Tokyo'
