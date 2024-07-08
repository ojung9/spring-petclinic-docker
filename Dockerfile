FROM eclipse-temurin:21-jdk-jammy

WORKDIR /app

# Build the application
COPY .mvn/ .mvn
COPY mvnw pom.xml ./
COPY src ./src
RUN ./mvnw clean package -DskipTests

# Copy HTML files to the target directory (assuming target directory is /app)
COPY src/main/resources/templates /app/templates

# Run the application
CMD ["java", "-jar", "target/*.jar"]

