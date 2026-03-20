#!/bin/bash

# 1. 환경 설정
BASE_DIR="/home/ubuntu/deployment/frontend"
NGINX_CONF_DIR="$BASE_DIR/nginx"
DOCKER_DIR="$BASE_DIR/docker"
COMPOSE_FILE="$DOCKER_DIR/docker-compose.yml"

if command -v docker-compose &> /dev/null; then
    DOCKER_COMPOSE="sudo docker-compose"
else
    DOCKER_COMPOSE="sudo docker compose"
fi

echo "--- 프론트엔드 도커 실행 환경 테스트 시작 ---"
cd "$DOCKER_DIR"

$DOCKER_COMPOSE config > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "❌ 에러: 도커 설정 파일($COMPOSE_FILE)이 없거나 .env 파일이 없습니다."
    exit 1
fi
echo "--- 프론트엔드 도커 실행 환경 테스트 통과 ---"

# 현재 실행 중인 컨테이너 확인 (frontend-blue 체크)
IS_BLUE=$($DOCKER_COMPOSE -f "$COMPOSE_FILE" ps | grep "frontend-blue" | grep "Up" || true)

if [ -z "$IS_BLUE" ]; then
  echo "### FE 배포 시작: GREEN => BLUE (8083) ###"

  $DOCKER_COMPOSE -f "$COMPOSE_FILE" pull frontend-blue || exit 1
  $DOCKER_COMPOSE -f "$COMPOSE_FILE" up -d frontend-blue || exit 1

  # 헬스체크 (React index.html 응답 확인)
  for i in {1..20}; do
    echo "3. Blue 헬스체크 중... ($i/20)"
    sleep 5
    REQUEST=$(curl -s http://127.0.0.1:8083 | grep "html" || true)
    if [ -n "$REQUEST" ]; then
      echo "✅ 헬스체크 성공!"
      break
    fi
    if [ $i -eq 20 ]; then
      echo "❌ 헬스체크 실패! 배포를 중단합니다."
      $DOCKER_COMPOSE -f "$COMPOSE_FILE" stop frontend-blue || true
      exit 1
    fi
  done

  echo "4. Nginx 설정 교체 (fe_blue.inc -> frontend.inc)"
  if [ -f "$NGINX_CONF_DIR/fe_blue.inc" ]; then
      sudo cp "$NGINX_CONF_DIR/fe_blue.inc" /etc/nginx/conf.d/frontend.inc
      sudo nginx -s reload
      echo "✅ Nginx FE 설정 로드 완료 (Blue)"
  else
      echo "❌ 에러: fe_blue.inc 파일을 찾을 수 없습니다."
      exit 1
  fi
  $DOCKER_COMPOSE -f "$COMPOSE_FILE" stop frontend-green || true

else
  echo "### FE 배포 시작: BLUE => GREEN (8084) ###"

  $DOCKER_COMPOSE -f "$COMPOSE_FILE" pull frontend-green || exit 1
  $DOCKER_COMPOSE -f "$COMPOSE_FILE" up -d frontend-green || exit 1

  for i in {1..20}; do
    echo "3. Green 헬스체크 중... ($i/20)"
    sleep 5
    REQUEST=$(curl -s http://127.0.0.1:8084 | grep "html" || true)
    if [ -n "$REQUEST" ]; then
      echo "✅ 헬스체크 성공!"
      break
    fi
    if [ $i -eq 20 ]; then
      echo "❌ 헬스체크 실패! 배포를 중단합니다."
      $DOCKER_COMPOSE -f "$COMPOSE_FILE" stop frontend-green || true
      exit 1
    fi
  done

  echo "4. Nginx 설정 교체 (fe_green.inc -> frontend.inc)"
  if [ -f "$NGINX_CONF_DIR/fe_green.inc" ]; then
      sudo cp "$NGINX_CONF_DIR/fe_green.inc" /etc/nginx/conf.d/frontend.inc
      sudo nginx -s reload
      echo "✅ Nginx FE 설정 로드 완료 (Green)"
  else
      echo "❌ 에러: fe_green.inc 파일을 찾을 수 없습니다."
      exit 1
  fi
  $DOCKER_COMPOSE -f "$COMPOSE_FILE" stop frontend-blue || true
fi
echo "🎊 프론트엔드 배포 완료!"