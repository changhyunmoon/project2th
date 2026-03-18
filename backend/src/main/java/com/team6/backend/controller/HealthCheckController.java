package com.team6.backend.controller;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.HashMap;
import java.util.Map;

@RestController
public class HealthCheckController {

    //나중에 여기 부분 security 설정에서 permitAll 해야됨

    @GetMapping
    public ResponseEntity<?> hello(){
        return ResponseEntity.ok("Hello World");
    }

    @GetMapping("/hc")
    public ResponseEntity<?> healthCheck(){

        return ResponseEntity.ok(200);
    }

    @GetMapping("/env")
    public ResponseEntity<?> getEnv(){
        return ResponseEntity.ok(200);
    }
}
