#!/bin/bash

# 1. 환경 설정
# GitHub Actions에서 보낸 파일들이 위치한 정확한 경로로 수정
BASE_DIR="$HOME/deployment/prod"
NGINX_CONF_DIR="$BASE_DIR/nginx"
COMPOSE_FILE="$BASE_DIR/docker/docker-compose.yml"
APP_NAME="team6"

# 도커 컴포즈 명령어 정의
if command -v docker-compose &> /dev/null; then
    DOCKER_COMPOSE="sudo docker-compose"
else
    DOCKER_COMPOSE="sudo docker compose"
fi

# [추가] 실행 전 docker 실행 권한 확인 (에러 발생 시 즉시 종료)
echo "--- 도커 권한 테스트 시작 ---"
$DOCKER_COMPOSE ps
if [ $? -ne 0 ]; then
    echo "❌ 에러: sudo 권한으로도 도커 명령어를 실행할 수 없습니다."
    echo "직접 'sudo docker ps'를 입력해서 확인해보세요."
    exit 1
fi
echo "--- 도커 권한 테스트 통과 ---"

# 현재 실행 중인 컨테이너 확인 (Up 상태인 blue가 있는지 체크)
IS_BLUE=$($DOCKER_COMPOSE -f "$COMPOSE_FILE" ps | grep "blue" | grep "Up" || true)

if [ -z "$IS_BLUE" ]; then
  echo "### 배포 시작: GREEN => BLUE (8081) ###"

  echo "1. Blue 이미지 가져오기"
  $DOCKER_COMPOSE -f "$COMPOSE_FILE" pull blue || exit 1

  echo "2. Blue 컨테이너 실행"
  $DOCKER_COMPOSE -f "$COMPOSE_FILE" up -d blue || exit 1

  # 헬스체크
  for i in {1..20}; do
    echo "3. Blue 헬스체크 중... ($i/20)"
    sleep 5
    # 컨테이너 내부 8080이 아닌, 호스트로 노출된 8081로 찌릅니다.
    REQUEST=$(curl -s http://127.0.0.1:8081/actuator/health | grep "UP" || true)
    if [ -n "$REQUEST" ]; then
      echo "✅ 헬스체크 성공!"
      break
    fi
    if [ $i -eq 20 ]; then
      echo "❌ 헬스체크 실패! 배포를 중단합니다."
      # 실패 시 방금 띄운 컨테이너는 정리
      $DOCKER_COMPOSE -f "$COMPOSE_FILE" stop blue || true
      exit 1
    fi
  done

  echo "4. Nginx 설정 교체 및 Reload"
  # Nginx 설정 파일이 존재하는지 확인 후 복사
  if [ -f "$NGINX_CONF_DIR/blue.conf" ]; then
      sudo cp "$NGINX_CONF_DIR/blue.conf" /etc/nginx/conf.d/default.conf
      sudo nginx -s reload
      echo "✅ Nginx 설정 로드 완료 (Blue)"
  else
      echo "❌ 에러: blue.conf 파일을 찾을 수 없습니다."
      exit 1
  fi

  echo "5. 이전 컨테이너(Green) 종료"
  $DOCKER_COMPOSE -f "$COMPOSE_FILE" stop green || true

else
  echo "### 배포 시작: BLUE => GREEN (8082) ###"

  echo "1. Green 이미지 가져오기"
  $DOCKER_COMPOSE -f "$COMPOSE_FILE" pull green || exit 1

  echo "2. Green 컨테이너 실행"
  $DOCKER_COMPOSE -f "$COMPOSE_FILE" up -d green || exit 1

  for i in {1..20}; do
    echo "3. Green 헬스체크 중... ($i/20)"
    sleep 5
    REQUEST=$(curl -s http://127.0.0.1:8082/actuator/health | grep "UP" || true)
    if [ -n "$REQUEST" ]; then
      echo "✅ 헬스체크 성공!"
      break
    fi
    if [ $i -eq 20 ]; then
      echo "❌ 헬스체크 실패! 배포를 중단합니다."
      $DOCKER_COMPOSE -f "$COMPOSE_FILE" stop green || true
      exit 1
    fi
  done

  echo "4. Nginx 설정 교체 및 Reload"
  if [ -f "$NGINX_CONF_DIR/green.conf" ]; then
      sudo cp "$NGINX_CONF_DIR/green.conf" /etc/nginx/conf.d/default.conf
      sudo nginx -s reload
      echo "✅ Nginx 설정 로드 완료 (Green)"
  else
      echo "❌ 에러: green.conf 파일을 찾을 수 없습니다."
      exit 1
  fi

  echo "5. 이전 컨테이너(Blue) 종료"
  $DOCKER_COMPOSE -f "$COMPOSE_FILE" stop blue || true
fi

echo "🎊 배포 완료!"