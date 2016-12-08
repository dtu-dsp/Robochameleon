function s = sumbitxor(a,b)

    if ~isvector(a) || ~isvector(b)
        roboerror('wrongInput','Both inputs must be vectors');
    end

    a = parseinput(a);
    b = parseinput(b);

    L = numel(a)-numel(b);
    if L<0
        [b,a] = deal(a,b); % swap variables in place
        L = -L;
    end
    
    nomem = warning('error','MATLAB:nomem'); %#ok<CTPCT> Change error to warning
    try
        s = uint32(xcorr(double(a),double(~b),L))+uint32(xcorr(double(~a),double(b),L));
        s = s(L+1:end);
    catch exception
        warning(nomem); % re-enable as error
        switch exception.identifier
            case nomem.identifier
                a = logical(a);
                b = logical(b);
                N = numel(b);

                s = zeros(L+1,1,'uint32');
                for ptr=0:L
                    s(ptr) = nnz(xor(a(ptr+(1:N)),b));
                end
            otherwise
                rethrow(exception);
        end   
    end

end



function x = parseinput(x)
    if ~isvector(x)
        roboerror('wrongInput','Both inputs must be vectors');
    elseif ~islogical(x)
        if ~isnumeric(x) || ~all(x==0 | x==1)
            roboerror('wrongInput','Input must be a numeric vector with zeros or ones only.');
        elseif verLessThan('matlab', '8.4.0') % Trick to save memory
            % Before MATLAB R2014b, input to xcorr must be double
            x = double(x);
        else
            % Since MATLAB R2014b, input to xcorr can be uint8
            x = uint8(x);
        end
    end
    x = x(:);
end