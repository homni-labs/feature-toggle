import 'package:fpdart/fpdart.dart';

import 'package:togli_app/core/domain/failure.dart';

typedef FutureEither<T> = Future<Either<Failure, T>>;
typedef FutureUnit = Future<Either<Failure, Unit>>;
