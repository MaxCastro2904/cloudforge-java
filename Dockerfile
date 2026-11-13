FROM maven:3.9.9-eclipse-temurin-21 AS build
WORKDIR /build
COPY app/pom.xml .
RUN mvn -B -ntp dependency:go-offline
COPY app/src ./src
RUN mvn -B -ntp clean verify

FROM eclipse-temurin:21-jre-alpine AS runtime
RUN addgroup -S app && adduser -S -G app -u 10001 app
WORKDIR /app
COPY --from=build --chown=app:app /build/target/app.jar /app/app.jar
USER app
ENV PORT=8080
EXPOSE 8080
ENTRYPOINT ["java", "-XX:MaxRAMPercentage=70.0", "-jar", "/app/app.jar"]
