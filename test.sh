#!bin/bash


go() {
    desc=$1
    func=$2
    echo $desc && $func
}

go "tesasdft" "echo ahah"