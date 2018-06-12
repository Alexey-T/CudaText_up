Скрипт для быстрой сборки CudaText.
Полная сборка на текущую платформу:
./cudaup.sh -g -I -m
Полная сборка на текущую платформу с путём до компилятора:
./cudaup.sh -g -I -m -l /путь/до/lazarus
Cross build:
./cudaup.sh -g -I -m -l -O system -C architecture 
