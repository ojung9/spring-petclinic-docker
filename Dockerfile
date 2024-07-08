FROM eclipse-temurin:21-jdk-jammy

WORKDIR /app

# Build the application
COPY .mvn/ .mvn
COPY mvnw pom.xml ./
COPY src ./src
RUN ./mvnw clean package -DskipTests

# Run the application
CMD ["java", "-jar", "target/*.jar"]
