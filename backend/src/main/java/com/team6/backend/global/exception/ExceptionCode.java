package com.team6.backend.global.exception;

import org.springframework.http.HttpStatus;

public interface ExceptionCode {

    HttpStatus getStatus();

    String getCode();

    String getMessage();

}