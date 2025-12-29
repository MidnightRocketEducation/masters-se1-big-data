extension Numeric {
	public static prefix func ++ (i: inout Self) -> Self {
		i += 1;
		return i;
	}

	public static prefix func -- (i: inout Self) -> Self {
		i -= 1;
		return i;
	}

	public static postfix func ++ (i: inout Self) -> Self {
		let old = i;
		i += 1;
		return old;
	}

	public static postfix func -- (i: inout Self) -> Self {
		let old = i;
		i -= 1;
		return old;
	}
}
