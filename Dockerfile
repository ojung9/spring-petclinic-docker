FROM eclipse-temurin:17-jdk-jammy as base
WORKDIR /app
COPY .mvn/ .mvn
COPY mvnw pom.xml ./
COPY src ./src

FROM base as build
RUN ./mvnw -DskipTests=true package

FROM eclipse-temurin:17-jre-jammy as production
WORKDIR /app
EXPOSE 8000
COPY --from=build /app/target/spring-petclinic-2.7.0-SNAPSHOT.jar /app/spring-petclinic-2.7.0-SNAPSHOT.jar
CMD ["java", "-jar", "spring-petclinic-2.7.0-SNAPSHOT.jar"]
