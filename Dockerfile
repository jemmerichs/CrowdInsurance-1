FROM node:4.2.4

ADD ExpressForDevelopment ExpressForDevelopment
ADD SmartInsurance SmartInsurance
RUN cd ExpressForDevelopment && npm install --loglevel warn
RUN cd ../SmartInsurance && npm install bower -g && npm install && bower install --allow-root
CMD ["cd", ExpressForDevelopment", "npm","start"]
