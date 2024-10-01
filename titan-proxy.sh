#!/bin/bash

# 색상 정의
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # 색상 초기화

# 변수 정의
PACKAGE_NAME="titan-edge_v0.1.20_246b9dd_linux-amd64.tar.gz"
DIR_NAME="titan-edge_v0.1.20_246b9dd_linux-amd64"
PROXY_FILE="proxy.txt"

# 1. 프록시 목록 사용자 입력
echo -e "${YELLOW}프록시 목록을 입력하세요 (종료는 '끝' 입력):${NC}"

# 프록시 목록을 proxy.txt 파일에 저장
> "$PROXY_FILE" # 파일 초기화
while true; do
    read -p "$(echo -e ${YELLOW}프록시를 입력하세요: ${NC})" proxy
    if [[ "$proxy" == "끝" ]]; then
        break
    fi
    echo "$proxy" >> "$PROXY_FILE"
done

# 2. 기존 작업 디렉토리 삭제
if [ -d "$DIR_NAME" ]; then
    echo -e "${YELLOW}기존 작업 디렉토리를 삭제합니다...${NC}"
    rm -rf "$DIR_NAME"
fi

# 3. 기존 패키지 삭제
if [ -f "$PACKAGE_NAME" ]; then
    echo -e "${YELLOW}기존 패키지를 삭제합니다...${NC}"
    rm -f "$PACKAGE_NAME"
fi

# 4. 패키지 다운로드
echo -e "${YELLOW}패키지를 다운로드합니다...${NC}"
wget https://github.com/Titannet-dao/titan-node/releases/download/v0.1.20/titan-edge_v0.1.20_246b9dd_linux-amd64.tar.gz

# 5. 다운로드한 파일 압축 해제
echo -e "${YELLOW}패키지를 추출합니다...${NC}"
tar -xzvf "$PACKAGE_NAME"

# 6. 작업 폴더로 이동
cd "$DIR_NAME" || { echo -e "${RED}디렉토리로 이동 실패${NC}"; exit 1; }

# 7. 권한 설정 및 파일 복사
echo -e "${YELLOW}파일을 복사합니다...${NC}"
sudo cp titan-edge /usr/local/bin
sudo cp libgoworkerd.so /usr/local/lib

# 8. 환경 변수 설정
echo -e "${YELLOW}환경 변수를 설정합니다...${NC}"
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib

# 9. 프록시 목록 읽기
while IFS= read -r proxy; do
    echo -e "${YELLOW}프록시: ${proxy}를 사용하여 식별코드를 얻으세요:${NC}"
    echo -e "${YELLOW}해당 사이트에 방문하여 식별코드를 얻으세요: ${NC}"
    echo -e "${YELLOW}https://titannet.gitbook.io/titan-network-en/resource-network-test/bind-the-identity-code${NC}"
    
    # 사용자로부터 식별 코드 입력 받기
    read -p "$(echo -e ${YELLOW}식별 코드를 입력하세요: ${NC})" identifier
    
    # 10. 바인드 명령 실행
    echo -e "${YELLOW}바인드 명령을 실행합니다...${NC}"
    titan-edge bind --hash="$identifier" https://api-test1.container1.titannet.io/api/v2/device/binding --proxy="$proxy"

    # 현재 사용 중인 포트 확인
    used_ports=$(netstat -tuln | awk '{print $4}' | grep -o '[0-9]*$' | sort -u)

    # 각 포트에 대해 ufw allow 실행
    for port in $used_ports; do
        echo -e "${GREEN}포트 ${port}을(를) 허용합니다.${NC}"
        sudo ufw allow $port
    done

    echo -e "${GREEN}모든 사용 중인 포트가 허용되었습니다.${NC}"
    
    # 11. 데몬 시작
    echo -e "${YELLOW}titan-edge 데몬을 시작합니다...${NC}"
    titan-edge daemon start --init --url https://cassini-locator.titannet.io:5000/rpc/v0 --proxy="$proxy"

done < "$PROXY_FILE"

echo -e "${GREEN}모든 프록시 작업이 완료되었습니다.${NC}"
