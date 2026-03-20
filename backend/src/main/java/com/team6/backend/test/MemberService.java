package com.team6.backend.test;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class MemberService {

    private final MemberRepository memberRepository;

    @Transactional
    public Long save(String name, String email){

        Member member = new Member(name, email);

        return memberRepository.save(member).getId();
    }

    @Transactional(readOnly = true)
    public Member find(Long id){
        return memberRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("member not found"));
    }
}