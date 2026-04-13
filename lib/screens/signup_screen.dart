import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SignUpScreen extends StatefulWidget {
  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  static const _ivory = Color(0xFFFFFCF5); // 밝은 크림 배경
  static const _amber = Color(0xFFFFB703); // 메인 옐로우
  static const _orange = Color(0xFFFB8500); // 버튼 포인트 오렌지
  static const _cocoa = Color(0xFF4E342E); // 브라운 텍스트
  static const _sand = Color(0xFFFFE082); // 연노랑 보조
  static const _error = Colors.red;

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeToTerms = false;

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_agreeToTerms) {
      _showErrorSnackBar('서비스 이용약관에 동의해주세요');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      print('이메일 회원가입 시작...');

      // 기존 로그인된 사용자 확인 (있으면 로그아웃)
      if (_auth.currentUser != null) {
        print('기존 로그인된 사용자 로그아웃 처리');
        await _auth.signOut();
        await Future.delayed(Duration(milliseconds: 300));
      }

      // Firebase 계정 생성을 더 안전하게 처리
      UserCredential? userCredential;
      try {
        userCredential = await _auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        print('✅ createUserWithEmailAndPassword 완료');
      } catch (createError) {
        print('❌ createUserWithEmailAndPassword 에러: $createError');

        // 타입 에러인 경우 잠시 후 현재 사용자 확인
        if (createError.toString().contains('PigeonUserDetails') ||
            createError.toString().contains('type cast') ||
            createError.toString().contains('List')) {
          print('타입 에러 감지 - 우회 처리');
          await Future.delayed(Duration(milliseconds: 1000));

          final currentUser = FirebaseAuth.instance.currentUser;
          if (currentUser != null &&
              currentUser.email?.toLowerCase() == _emailController.text.trim().toLowerCase()) {
            print('✅ 타입 에러 무시하고 진행 (실제로는 성공)');
            // 성공 처리로 진행
          } else {
            // 실제로 실패한 경우
            rethrow;
          }
        } else {
          // 다른 종류의 에러
          rethrow;
        }
      }

      // 사용자 정보를 안전하게 가져오기
      User? user;
      try {
        // userCredential이 있는 경우 먼저 시도
        if (userCredential != null) {
          user = userCredential.user;
        }

        // userCredential이 없거나 user가 null인 경우 currentUser로 시도
        if (user == null) {
          await Future.delayed(Duration(milliseconds: 500));
          user = FirebaseAuth.instance.currentUser;
        }

        print('사용자 정보 확인: ${user?.email}');
      } catch (userError) {
        print('사용자 정보 가져오기 오류: $userError');
        // 에러가 발생해도 currentUser로 다시 시도
        await Future.delayed(Duration(milliseconds: 500));
        user = FirebaseAuth.instance.currentUser;
      }

      // 사용자가 실제로 생성되었는지 확인
      if (user == null || user.email?.toLowerCase() != _emailController.text.trim().toLowerCase()) {
        throw Exception('사용자 계정이 생성되지 않았습니다.');
      }

      print('회원가입 성공: ${user.email}');
      print('사용자 UID: ${user.uid}');

      // 사용자 프로필 업데이트를 별도의 try-catch로 처리
      try {
        await user.updateDisplayName(_nameController.text.trim());
        await user.reload();
        print('프로필 업데이트 성공');
      } catch (profileError) {
        print('프로필 업데이트 실패: $profileError');
        // 프로필 업데이트 실패해도 계속 진행
      }

      // 이메일 인증 발송
      try {
        await user.sendEmailVerification();
        print('이메일 인증 발송 성공');
      } catch (emailError) {
        print('이메일 인증 발송 실패: $emailError');
        // 이메일 발송 실패해도 계속 진행
      }

      // 성공 다이얼로그 표시
      if (mounted) {
        _showSuccessDialog();
      }

    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException 발생:');
      print('Code: ${e.code}');
      print('Message: ${e.message}');

      if (mounted) {
        _handleFirebaseAuthError(e);
      }

    } catch (e) {
      print('일반 오류 발생: $e');
      print('오류 타입: ${e.runtimeType}');

      // 타입 캐스팅 에러인 경우 특별 처리 (PigeonUserDetails 또는 List 관련)
      if (e.toString().contains('PigeonUserDetails') ||
          e.toString().contains('type cast') ||
          e.toString().contains('List') ||
          e.toString().contains('subtype')) {
        print('Firebase Auth 타입 호환성 문제 감지 - 우회 처리 시작');

        // 에러 발생해도 실제로 계정이 생성되었을 가능성이 높으므로 확인
        try {
          print('실제 회원가입 상태 확인 중...');
          await Future.delayed(Duration(milliseconds: 1500));

          // 현재 인증된 사용자 확인
          final currentUser = FirebaseAuth.instance.currentUser;
          print('현재 사용자: ${currentUser?.email}');

          if (currentUser != null &&
              currentUser.email?.toLowerCase() == _emailController.text.trim().toLowerCase()) {
            print('✅ 회원가입이 실제로 성공함 (타입 에러 무시)');

            // 프로필 업데이트 시도
            try {
              if (currentUser.displayName == null || currentUser.displayName!.isEmpty) {
                await currentUser.updateDisplayName(_nameController.text.trim());
                await currentUser.reload();
                print('프로필 업데이트 완료');
              }
            } catch (profileError) {
              print('프로필 업데이트 실패 (무시): $profileError');
            }

            // 이메일 인증 발송 시도
            try {
              if (!currentUser.emailVerified) {
                await currentUser.sendEmailVerification();
                print('이메일 인증 발송 완료');
              }
            } catch (emailError) {
              print('이메일 인증 발송 실패 (무시): $emailError');
            }

            if (mounted) {
              _showSuccessDialog();
            }
            return;
          } else {
            print('❌ 실제로 회원가입 실패');
          }
        } catch (verifyError) {
          print('상태 확인 중 오류: $verifyError');
        }
      }

      // 다른 종류의 에러이거나 실제로 실패한 경우
      if (mounted) {
        _showErrorSnackBar(
            '회원가입 중 오류가 발생했습니다.\n잠시 후 다시 시도해주세요.'
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

  void _handleFirebaseAuthError(FirebaseAuthException e) {
    String errorMessage;
    switch (e.code) {
      case 'email-already-in-use':
        errorMessage = '이미 사용 중인 이메일입니다.\n다른 이메일을 사용해주세요.';
        break;
      case 'weak-password':
        errorMessage = '비밀번호가 너무 약합니다.\n영문자와 숫자를 포함해서 6자 이상 입력해주세요.';
        break;
      case 'invalid-email':
        errorMessage = '유효하지 않은 이메일 형식입니다.';
        break;
      case 'operation-not-allowed':
        errorMessage = '이메일 회원가입이 비활성화되어 있습니다.';
        break;
      case 'network-request-failed':
        errorMessage = '네트워크 연결을 확인해주세요.';
        break;
      case 'too-many-requests':
        errorMessage = '너무 많은 시도를 했습니다.\n잠시 후 다시 시도해주세요.';
        break;
      default:
        errorMessage = '회원가입 중 오류가 발생했습니다.\n${e.message ?? '알 수 없는 오류'}';
    }

    _showErrorSnackBar(errorMessage);
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: _error,
          duration: Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showSuccessDialog() {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Colors.white,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 64,
              ),
              SizedBox(height: 16),
              Text(
                '회원가입 완료!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _cocoa,
                ),
              ),
              SizedBox(height: 8),
              Text(
                '${_nameController.text}님, 환영합니다!\n인증 이메일을 확인해주세요.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: _cocoa,
                ),
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // 다이얼로그 닫기
                  Navigator.of(context).pop(); // 회원가입 페이지 닫기
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _amber,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  '로그인 페이지로 이동',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _cocoa,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '이름을 입력해주세요';
    }
    if (value.trim().length < 2) {
      return '이름은 최소 2자 이상이어야 합니다';
    }
    if (value.trim().length > 20) {
      return '이름은 20자 이하여야 합니다';
    }
    // 특수문자 체크 (한글, 영문만 허용)
    if (!RegExp(r'^[가-힣a-zA-Z\s]+$').hasMatch(value.trim())) {
      return '이름은 한글 또는 영문만 입력 가능합니다';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '이메일을 입력해주세요';
    }
    // 더 정확한 이메일 정규식
    if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(value.trim())) {
      return '유효한 이메일 형식을 입력해주세요';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return '비밀번호를 입력해주세요';
    }
    if (value.length < 6) {
      return '비밀번호는 최소 6자 이상이어야 합니다';
    }
    if (value.length > 20) {
      return '비밀번호는 20자 이하여야 합니다';
    }
    if (!RegExp(r'^(?=.*[a-zA-Z])(?=.*[0-9])').hasMatch(value)) {
      return '비밀번호는 영문자와 숫자를 포함해야 합니다';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return '비밀번호 확인을 입력해주세요';
    }
    if (value != _passwordController.text) {
      return '비밀번호가 일치하지 않습니다';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // 선택사항
    }
    // 다양한 형식 허용 (010-1234-5678, 01012345678 등)
    String cleanPhone = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (!RegExp(r'^01[0-9]{8,9}$').hasMatch(cleanPhone)) {
      return '올바른 휴대폰 번호 형식이 아닙니다 (예: 010-1234-5678)';
    }
    return null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // 배경을 연한 그라데이션으로
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFE186), // 밝은 옐로우
              Color(0xFFFFEDB9), // 크림톤
              Color(0xFFFFDAD6), // 살짝 핑크톤
            ],
            stops: [0.0, 0.29, 0.71], // 각 색이 차지하는 구간 비율
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 상단 헤더
              Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.arrow_back, color: _cocoa),
                    ),
                    Expanded(
                      child: Text(
                        '회원가입',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: _cocoa,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(width: 48), // 균형 맞추기용
                  ],
                ),
              ),

              // 스크롤 가능한 폼 영역
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 환영 메시지
                        Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.person_add,
                                size: 80,
                                color: _cocoa,
                              ),
                              SizedBox(height: 16),
                              Text(
                                '독서 기록장과 함께\n새로운 여정을 시작하세요!',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 18,
                                  color: _cocoa,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 40),

                        // 입력 필드들
                        _buildTextField(
                          controller: _nameController,
                          label: '이름',
                          icon: Icons.person,
                          validator: _validateName,
                          textInputAction: TextInputAction.next,
                        ),

                        SizedBox(height: 20),

                        _buildTextField(
                          controller: _emailController,
                          label: '이메일',
                          icon: Icons.email,
                          validator: _validateEmail,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                        ),

                        SizedBox(height: 20),

                        _buildTextField(
                          controller: _phoneController,
                          label: '휴대폰 번호 (선택사항)',
                          icon: Icons.phone,
                          validator: _validatePhone,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
                          hint: '010-1234-5678',
                        ),

                        SizedBox(height: 20),

                        _buildTextField(
                          controller: _passwordController,
                          label: '비밀번호',
                          icon: Icons.lock,
                          validator: _validatePassword,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.next,
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                            icon: Icon(
                              _obscurePassword ? Icons.visibility : Icons.visibility_off,
                              color: _cocoa.withOpacity(0.7),
                            ),
                          ),
                        ),

                        SizedBox(height: 20),

                        _buildTextField(
                          controller: _confirmPasswordController,
                          label: '비밀번호 확인',
                          icon: Icons.lock_outline,
                          validator: _validateConfirmPassword,
                          obscureText: _obscureConfirmPassword,
                          textInputAction: TextInputAction.done,
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                _obscureConfirmPassword = !_obscureConfirmPassword;
                              });
                            },
                            icon: Icon(
                              _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                              color: _cocoa.withOpacity(0.7),
                            ),
                          ),
                        ),

                        SizedBox(height: 30),

                        // 이용약관 동의 체크박스
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              Checkbox(
                                value: _agreeToTerms,
                                onChanged: (value) {
                                  setState(() {
                                    _agreeToTerms = value ?? false;
                                  });
                                },
                                activeColor: _amber,
                                checkColor: _cocoa,
                              ),
                              Expanded(
                                child: Text(
                                  '서비스 이용약관 및 개인정보처리방침에 동의합니다',
                                  style: TextStyle(
                                    color: _cocoa,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 30),

                        // 회원가입 버튼
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _signUp,
                            child: _isLoading
                                ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(_cocoa),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text(
                                  '가입 중...',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: _cocoa,
                                  ),
                                ),
                              ],
                            )
                                : Text(
                              '회원가입 완료',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: _cocoa,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              disabledBackgroundColor: Colors.grey[300],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 2,
                            ),
                          ),
                        ),

                        SizedBox(height: 20),

                        // 로그인 페이지로 이동
                        Center(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              '이미 계정이 있으신가요? 로그인',
                              style: TextStyle(
                                color: _cocoa,
                                fontSize: 14,
                                decoration: TextDecoration.underline,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    bool obscureText = false,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    Widget? suffixIcon,
    String? hint,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      style: TextStyle(color: _cocoa, fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(color: _cocoa.withOpacity(0.7)),
        hintStyle: TextStyle(color: _cocoa.withOpacity(0.5)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.9),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _amber.withOpacity(0.3), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _amber, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _error, width: 2),
        ),
        prefixIcon: Icon(icon, color: _amber),
        suffixIcon: suffixIcon,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}