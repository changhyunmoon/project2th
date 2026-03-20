package com.team6.backend.test;

import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

@RestController
@RequiredArgsConstructor
@RequestMapping("/member")
public class MemberController {

    private final MemberService memberService;

    @PostMapping
    public Long save(@RequestBody MemberRequest request){

        return memberService.save(
                request.getName(),
                request.getEmail()
        );
    }

    @GetMapping("/{id}")
    public Member find(@PathVariable Long id){

        return memberService.find(id);
    }
}