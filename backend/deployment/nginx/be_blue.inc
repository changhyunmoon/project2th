# 백엔드 Blue 메인 API 경로 (8081 포트)
location /api/ {
    proxy_pass http://127.0.0.1:8080;
    proxy_http_version 1.1;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
}

location /api/actuator/health {
    proxy_pass http://127.0.0.1:8080/api/actuator/health;
    access_log off;
}


지금 ec2에서 nginx를 이용해서 프론트와 백엔드 서버에 대한 리버스 프록시를 설정하려고해.

http://43.202.182.58이건 ec2 ip 주소이고,

브라우저에서 80포트로 들어오면 프론트 서버로, 8080 포트로 들어오면 백엔드 서버로 접속할 수 있게 하고싶어.