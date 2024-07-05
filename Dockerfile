# Base image
FROM eclipse-temurin:21-jdk-jammy

# Set the working directory
WORKDIR /app

# Copy the Maven wrapper and the pom.xml
COPY .mvn/ .mvn
COPY mvnw pom.xml ./

# Download Maven dependencies
RUN ./mvnw dependency:resolve

# Copy the source code
COPY src ./src

# Build the application
RUN ./mvnw package

# Copy the built JAR file to the Docker image
COPY target/*.jar app.jar

# Expose the application port
EXPOSE 8080

# Run the application
CMD ["java", "-jar", "app.jar"]

