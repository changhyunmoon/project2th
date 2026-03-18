#베이스 이미지 및 환경 설정
FROM eclipse-temurin:17-jre
ENV TZ=Asia/Seoul
ARG JAR_FILE=build/libs/*.jar

#패키지 관리 및 보안
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

RUN addgroup --system spring && adduser --system --group spring
USER spring:spring

#복사 및 실행
COPY --chown=spring:spring ${JAR_FILE} app.jar

HEALTHCHECK --start-period=30s --interval=10s --timeout=5s --retries=5 \
  CMD sh -c 'curl -f http://localhost:8080/api/actuator/health || exit 1'

ENTRYPOINT ["sh", "-c", "exec java $JAVA_OPTS -jar app.jar"]