import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _auth = FirebaseAuth.instance;
  bool _isLoading = false;
  bool _isSignUp = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        if (_isSignUp) {
          // 회원가입
          await _auth.createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('회원가입이 완료되었습니다!')),
            );
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const HomePage()),
            );
          }
        } else {
          // 로그인
          await _auth.signInWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('로그인되었습니다!')),
            );
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const HomePage()),
            );
          }
        }
      } on FirebaseAuthException catch (e) {
        String message = '오류가 발생했습니다.';
        if (e.code == 'weak-password') {
          message = '비밀번호가 너무 약합니다.';
        } else if (e.code == 'email-already-in-use') {
          message = '이미 사용 중인 이메일입니다.';
        } else if (e.code == 'user-not-found') {
          message = '해당 이메일로 등록된 사용자가 없습니다.';
        } else if (e.code == 'wrong-password') {
          message = '잘못된 비밀번호입니다.';
        } else if (e.code == 'invalid-email') {
          message = '유효하지 않은 이메일 형식입니다.';
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('오류가 발생했습니다: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isSignUp ? '회원가입' : '로그인'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 로고 또는 앱 이름
              const Icon(
                Icons.book,
                size: 80,
                color: Colors.blue,
              ),
              const SizedBox(height: 20),
              Text(
                'My Diary',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 40),
              
              // 이메일 입력 필드
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: '이메일',
                  hintText: 'example@email.com',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '이메일을 입력해주세요';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                    return '유효한 이메일 형식을 입력해주세요';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // 비밀번호 입력 필드
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: '비밀번호',
                  hintText: '비밀번호를 입력하세요',
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '비밀번호를 입력해주세요';
                  }
                  if (value.length < 6) {
                    return '비밀번호는 최소 6자 이상이어야 합니다';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              
              // 로그인/회원가입 버튼
              ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        _isSignUp ? '회원가입' : '로그인',
                        style: const TextStyle(fontSize: 16),
                      ),
              ),
              const SizedBox(height: 16),
              
              // 로그인/회원가입 모드 전환 버튼
              TextButton(
                onPressed: () {
                  setState(() {
                    _isSignUp = !_isSignUp;
                  });
                },
                child: Text(
                  _isSignUp
                      ? '이미 계정이 있으신가요? 로그인하기'
                      : '계정이 없으신가요? 회원가입하기',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 