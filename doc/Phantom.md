뒤에 숨었을때 나오는것


phantom shader

##

벽
오브젝트
오브젝트 아웃라인

Ztest Always

- 표시하고싶은걸 z-test 로 항상 앞으로(오브젝트 아웃라인)
- 벽 stensil 1로
- 오브젝트 stensil 2로



stensil
{
	 pass   replace //비교에 성공하면 스텐실 버퍼 에 ref 값을 기록해라
	 pass   keep // 비교에 성공하면 스텐실버퍼값을 유지해라
}

##
- http://lwsoft.egloos.com/5860193
