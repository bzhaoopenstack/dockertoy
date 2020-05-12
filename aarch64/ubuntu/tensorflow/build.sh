apt update && apt install build-essential openjdk-8-jdk python zip unzip gcc python-pip libhdf5-serial-dev git pkg-config wget sudo -y
 
 useradd -m -d /home/test -s /bin/bash test && echo test:test | chpasswd && adduser test sudo
 echo "test ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
 
 
USER test
WORKDIR /home/test


pip install numpy future keras_preprocessing mock 

wget https://github.com/bazelbuild/bazel/releases/download/0.26.0/bazel-0.26.0-dist.zip

mkdir bazel
unzip bazel-0.26.0-dist.zip -d bazel 
cd bazel 
EXTRA_BAZEL_ARGS='--host_javabase=@local_jdk//:jdk' ./compile.sh 
sudo ln -s `pwd`/output/bazel /usr/bin/bazel


sudo apt install python3 python3-dev
sudo pip install virtualenv 

virtualenv --python=python2.7 ~/.env/tensorflow/ 

virtualenv --python=python3.6 ~/.env/tensorflow/

source ~/.env/tensorflow/bin/activate 

#deactivate

git clone https://github.com/tensorflow/tensorflow.git

cd tensorflow

wget https://github.com/tensorflow/tensorflow/archive/v2.0.0.tar.gz 

tar -xvf v2.0.0.tar.gz 

cd tensorflow-2.0.0 

./configure

Extracting Bazel installation... WARNING: --batch mode is deprecated. Please instead explicitly shut down your Bazel server using the command "bazel shutdown". You have bazel 0.26.0- (@non-git) installed. Please specify the location of python. [Default is /usr/bin/python]: [Enter] Please input the desired Python library path to use.  Default is [/usr/local/lib/python2.7/dist-packages] [Enter] Do you wish to build TensorFlow with XLA JIT support? [Y/n]: n No XLA JIT support will be enabled for TensorFlow.
 Do you wish to build TensorFlow with OpenCL SYCL support? [y/N]: n No OpenCL SYCL support will be enabled for TensorFlow.
 Do you wish to build TensorFlow with ROCm support? [y/N]: n No ROCm support will be enabled for TensorFlow.
 Do you wish to build TensorFlow with CUDA support? [y/N]: n No CUDA support will be enabled for TensorFlow.
 Do you wish to download a fresh release of clang? (Experimental) [y/N]: n Clang will not be downloaded.
 Do you wish to build TensorFlow with MPI support? [y/N]: n No MPI support will be enabled for TensorFlow.
 Please specify optimization flags to use during compilation when bazel option "--config=opt" is specified [Default is -march=native -Wno-signcompare]: [Enter]
 Would you like to interactively configure ./WORKSPACE for Android builds? [y/N]: n Not configuring the WORKSPACE for Android builds.

pip install numpy keras_preprocessing

bazel clean --expunge


bazel build --config=opt //tensorflow/tools/pip_package:build_pip_package --local_ram_resources=2048 --local_cpu_resources=2
mkdir tensorflow-pkg
bazel-bin/tensorflow/tools/pip_package/build_pip_package ./tensorflow-pkg 

生产的whl文件在tensorflow_pkg目录下 


apt install build-essential gcc libhdf5-serial-dev pkg-config 
apt install python python-pip 
apt install python3 python3-pip 
pip install tensorflow-*.whl  
python -c "import tensorflow as tf; print(tf.__version__)" 

=====================
master build
=====================
sudo apt install protobuf-compiler -y
wget https://github.com/bazelbuild/bazel/releases/download/3.1.0/bazel-3.1.0-dist.zip
mkdir bazel3

unzip bazel-3.1.0-dist.zip -d bazel3
cd bazel3/
# export PROTOC=`which protoc`
EXTRA_BAZEL_ARGS='--host_javabase=@local_jdk//:jdk' ./compile.sh 
sudo ln -s `pwd`/output/bazel /usr/bin/bazel3


sudo apt install python3 python3-dev
sudo pip install virtualenv 

virtualenv --python=python2.7 ~/.env/tensorflow/ 

virtualenv --python=python3.6 ~/.env/tensorflow/

source ~/.env/tensorflow/bin/activate 

#deactivate

git clone https://github.com/tensorflow/tensorflow.git

cd tensorflow

./configure

Extracting Bazel installation... WARNING: --batch mode is deprecated. Please instead explicitly shut down your Bazel server using the command "bazel shutdown". You have bazel 0.26.0- (@non-git) installed. Please specify the location of python. [Default is /usr/bin/python]: [Enter] Please input the desired Python library path to use.  Default is [/usr/local/lib/python2.7/dist-packages] [Enter] 
Do you wish to build TensorFlow with XLA JIT support? [Y/n]: n No XLA JIT support will be enabled for TensorFlow.
 Do you wish to build TensorFlow with OpenCL SYCL support? [y/N]: n No OpenCL SYCL support will be enabled for TensorFlow.
 Do you wish to build TensorFlow with ROCm support? [y/N]: n No ROCm support will be enabled for TensorFlow.
 Do you wish to build TensorFlow with CUDA support? [y/N]: n No CUDA support will be enabled for TensorFlow.
 Do you wish to download a fresh release of clang? (Experimental) [y/N]: n Clang will not be downloaded.
 Do you wish to build TensorFlow with MPI support? [y/N]: n No MPI support will be enabled for TensorFlow.
 Please specify optimization flags to use during compilation when bazel option "--config=opt" is specified [Default is -march=native -Wno-signcompare]: [Enter]
 Would you like to interactively configure ./WORKSPACE for Android builds? [y/N]: n Not configuring the WORKSPACE for Android builds.

pip install numpy keras_preprocessing

bazel3 clean --expunge


bazel3 build --config=opt //tensorflow/tools/pip_package:build_pip_package --local_ram_resources=2048 --local_cpu_resources=2 --config noaws
mkdir tensorflow-pkg
bazel-bin/tensorflow/tools/pip_package/build_pip_package ./tensorflow-pkg 

生产的whl文件在tensorflow_pkg目录下 


apt install build-essential gcc libhdf5-serial-dev pkg-config 
apt install python python-pip 
apt install python3 python3-pip 
pip install tensorflow-*.whl  
python -c "import tensorflow as tf; print(tf.__version__)" 
