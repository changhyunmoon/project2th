# 1단계: 빌드
FROM node:20-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build

# 2단계: 실행 (Nginx)
FROM nginx:stable-alpine
# 빌드 결과물을 Nginx의 기본 정적 파일 경로로 복사
COPY --from=build /app/dist /usr/share/nginx/html
# (Vite 기준 dist, CRA라면 build로 수정)
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]