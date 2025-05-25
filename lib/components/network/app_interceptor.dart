import 'package:dio/dio.dart';
import 'package:todo_app/components/network/dio_helper.dart';
import 'package:todo_app/features/auth/data_layer/data_source/auth_local_datasorce.dart';

class AppInterceptor extends Interceptor {
  AppInterceptor();

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // if (await AuthLocalDatasorce().getRefreshToken() == null) {
    //   super.onError(err, handler);
    //   return null;
    // }
    print("ERROR INTERCEPTOR : ${err.message}");
    print('hahahah');
    print(await AuthLocalDatasorce().getRefreshToken());
    print('hahahah');
    // If response is 401 and refresh token is available
    if (err.response?.statusCode == 401 &&
        await AuthLocalDatasorce().getRefreshToken() != null) {
      try {
        final refreshToken = await AuthLocalDatasorce().getRefreshToken();

        // Call refresh token API
        final response = await DioHelper.getData(
          endPoint: "/auth/refresh-token",
          query: {"token": refreshToken},
        );

        if (response.statusCode == 200 &&
            response.data['access_token'] != null) {
          // Save the new access token
          AuthLocalDatasorce().saveAccessToken(response.data['access_token']);

          // Update token in DioHelper
          DioHelper.token = response.data['access_token'];

          // Retry the original request with the new token
          final options = err.requestOptions;
          options.headers['Authorization'] = 'Bearer ${DioHelper.token}';

          final clonedResponse = await Dio().fetch(options);
          return handler.resolve(clonedResponse);
        }
      } catch (e) {
        print('Token refresh failed: $e');
      }
    }

    // Forward the error if it wasn't handled
    super.onError(err, handler);
  }
}
